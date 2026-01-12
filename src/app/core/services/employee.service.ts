import { Injectable } from '@angular/core';
import { SupabaseService } from './supabase.service';
import { Employee } from '../models';

@Injectable({
    providedIn: 'root'
})
export class EmployeeService {
    constructor(private supabase: SupabaseService) { }

    async getAll() {
        return await this.supabase
            .from('employees')
            .select('*')
            .order('full_name');
    }

    async getById(id: string) {
        return await this.supabase
            .from('employees')
            .select('*')
            .eq('id', id)
            .single();
    }

    async create(employee: Partial<Employee>) {
        return await this.supabase
            .from('employees')
            .insert(employee)
            .select()
            .single();
    }

    async update(id: string, employee: Partial<Employee>) {
        return await this.supabase
            .from('employees')
            .update(employee)
            .eq('id', id)
            .select()
            .single();
    }

    async delete(id: string) {
        return await this.supabase
            .from('employees')
            .delete()
            .eq('id', id);
    }

    async toggleStatus(id: string, status: 'active' | 'inactive') {
        return await this.update(id, { status });
    }
}
